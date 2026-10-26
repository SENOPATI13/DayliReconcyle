-- ============================================================
-- SKEMA DATABASE SISTEM REKONSILIASI
-- Compatible with: PostgreSQL / MySQL / SQLite
-- ============================================================

-- 1. Tabel Master Batch / Sesi Rekonsiliasi
CREATE TABLE IF NOT EXISTS recon_batches (
    batch_id VARCHAR(50) PRIMARY KEY,
    recon_type VARCHAR(20) NOT NULL, -- 'REGULAR' atau 'STO'
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    template_filename VARCHAR(255),
    monitoring_filename VARCHAR(255),
    total_records_template INT DEFAULT 0,
    total_records_monitoring INT DEFAULT 0,
    matched_count INT DEFAULT 0,
    qty_mismatch_count INT DEFAULT 0,
    attr_mismatch_count INT DEFAULT 0,
    vendor_mismatch_count INT DEFAULT 0,
    driver_mismatch_count INT DEFAULT 0,
    truck_no_mismatch_count INT DEFAULT 0,
    truck_type_mismatch_count INT DEFAULT 0,
    unmatched_template_count INT DEFAULT 0,
    unmatched_monitoring_count INT DEFAULT 0
);

-- 2. Tabel Staging Data Template (Regular & STO)
CREATE TABLE IF NOT EXISTS recon_template_data (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(50) NOT NULL,
    dn_no VARCHAR(100) NOT NULL,
    material_code VARCHAR(100) NOT NULL,
    pick_qty NUMERIC(15, 4) DEFAULT 0,
    vendor_name VARCHAR(255),
    truck_no VARCHAR(100),
    operator_name VARCHAR(255),
    truck_type VARCHAR(100),
    FOREIGN KEY (batch_id) REFERENCES recon_batches(batch_id) ON DELETE CASCADE
);

-- 3. Tabel Staging Data Monitoring Harian
CREATE TABLE IF NOT EXISTS recon_monitoring_data (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(50) NOT NULL,
    dn_no VARCHAR(100) NOT NULL,
    material_code VARCHAR(100) NOT NULL,
    actual_qty NUMERIC(15, 4) DEFAULT 0,
    vendor_name VARCHAR(255),
    truck_no VARCHAR(100),
    driver_name VARCHAR(255),
    truck_type VARCHAR(100),
    FOREIGN KEY (batch_id) REFERENCES recon_batches(batch_id) ON DELETE CASCADE
);

-- 4. Tabel Hasil Laporan Rekonsiliasi (Discrepancy & Match Results)
CREATE TABLE IF NOT EXISTS recon_results (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(50) NOT NULL,
    composite_key VARCHAR(255) NOT NULL, -- DN_NO + '___' + MATERIAL_CODE
    dn_no VARCHAR(100) NOT NULL,
    material_code VARCHAR(100) NOT NULL,
    
    -- Data Template
    template_qty NUMERIC(15, 4),
    template_vendor VARCHAR(255),
    template_truck_no VARCHAR(100),
    template_operator VARCHAR(255),
    template_truck_type VARCHAR(100),
    
    -- Data Monitoring
    monitoring_qty NUMERIC(15, 4),
    monitoring_vendor VARCHAR(255),
    monitoring_truck_no VARCHAR(100),
    monitoring_driver VARCHAR(255),
    monitoring_truck_type VARCHAR(100),
    
    -- Status & Diff Detail
    qty_diff NUMERIC(15, 4) DEFAULT 0,
    status_summary VARCHAR(50) NOT NULL, -- 'MATCHED', 'QTY_MISMATCH', 'ATTR_MISMATCH', 'ONLY_IN_TEMPLATE', 'ONLY_IN_MONITORING'
    mismatch_details TEXT, -- Deskripsi detail atribut yang beda
    FOREIGN KEY (batch_id) REFERENCES recon_batches(batch_id) ON DELETE CASCADE
);

-- Indexing untuk performa pencarian kunci komposit
CREATE INDEX idx_recon_res_batch_key ON recon_results(batch_id, composite_key);
CREATE INDEX idx_recon_res_status ON recon_results(status_summary);
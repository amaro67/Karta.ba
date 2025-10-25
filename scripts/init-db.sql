-- Database initialization script for Karta.ba
-- This script runs when SQL Server container starts for the first time

-- Create the KartaDb database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'KartaDb')
BEGIN
    CREATE DATABASE KartaDb;
END

-- Use the KartaDb database
USE KartaDb;

-- Log initialization
PRINT 'Karta.ba database initialized successfully';

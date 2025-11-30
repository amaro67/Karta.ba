using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Karta.Model.Migrations
{
    /// <inheritdoc />
    public partial class AddScannerAssignments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CreatedByOrganizerId",
                table: "AspNetUsers",
                type: "TEXT",
                maxLength: 450,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "EventScannerAssignments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    EventId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ScannerUserId = table.Column<string>(type: "TEXT", maxLength: 450, nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventScannerAssignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventScannerAssignments_AspNetUsers_ScannerUserId",
                        column: x => x.ScannerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EventScannerAssignments_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_EventScannerAssignments_EventId_ScannerUserId",
                table: "EventScannerAssignments",
                columns: new[] { "EventId", "ScannerUserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventScannerAssignments_ScannerUserId",
                table: "EventScannerAssignments",
                column: "ScannerUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EventScannerAssignments");

            migrationBuilder.DropColumn(
                name: "CreatedByOrganizerId",
                table: "AspNetUsers");
        }
    }
}

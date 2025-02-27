
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        LEN(REPLACE(REPLACE(p.Tags, '><', ','), '<', '')) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),

FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.PostType,
        rp.TagCount
    FROM
        RankedPosts rp
    WHERE
        rp.UserPostRank <= 5 
),

TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(f.PostId) AS PostCount,
        SUM(f.ViewCount) AS TotalViews,
        SUM(f.Score) AS TotalScore
    FROM
        Users u
    JOIN
        FilteredPosts f ON u.Id = f.PostId
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        PostCount DESC, TotalViews DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)

SELECT
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CreationDate
FROM
    TopUsers tu
JOIN
    FilteredPosts fp ON tu.UserId = fp.PostId
ORDER BY
    tu.TotalScore DESC, fp.ViewCount DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        AuthorDisplayName,
        CreationDate,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
),
TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TotalCount
    FROM 
        FilteredPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.Title,
    fp.Body,
    fp.AuthorDisplayName,
    fp.CreationDate,
    fp.Score,
    ts.TagName,
    ts.TotalCount,
    us.DisplayName AS UserName,
    us.BadgeCount,
    us.TotalBounty
FROM 
    FilteredPosts fp
JOIN 
    TagStats ts ON ts.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', numbers.n), '><', -1)
JOIN 
    UserStats us ON us.DisplayName = fp.AuthorDisplayName
ORDER BY 
    fp.CreationDate DESC;

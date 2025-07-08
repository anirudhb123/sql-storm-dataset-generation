
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
        TRIM(value) AS TagName,
        COUNT(*) AS TotalCount
    FROM 
        FilteredPosts,
        LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS value
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
    TagStats ts ON ts.TagName = fp.Tags 
JOIN 
    UserStats us ON us.DisplayName = fp.AuthorDisplayName
ORDER BY 
    fp.CreationDate DESC;

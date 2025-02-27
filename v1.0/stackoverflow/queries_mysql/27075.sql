
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1) AS Tag
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1
)
SELECT 
    rp.OwnerUserId AS UserId,
    ud.DisplayName,
    ud.Reputation,
    COUNT(tp.Tag) AS TagCount,
    SUM(CASE WHEN rp.Rank = 1 THEN 1 ELSE 0 END) AS LatestQuestionCount,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalScore,
    MAX(rp.CreationDate) AS LastActivityDate
FROM 
    RankedPosts rp
JOIN 
    UserDetails ud ON rp.OwnerUserId = ud.UserId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
GROUP BY 
    rp.OwnerUserId, ud.DisplayName, ud.Reputation
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;

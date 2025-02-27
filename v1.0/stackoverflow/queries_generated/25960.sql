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
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= '2020-01-01' -- Consider questions created after start of 2020
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount, -- Count of distinct posts per tag
        SUM(p.ViewCount) AS TotalViews, -- Sum of views for those posts
        AVG(p.Score) AS AverageScore -- Average score of those posts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    ts.AverageScore AS TagAverageScore,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.QuestionsCount AS OwnerQuestionsCount,
    ur.TotalBounty AS OwnerTotalBounty
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%' -- Join post with its tags statistics
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId -- Join user reputation info
WHERE 
    rp.ScoreRank = 1 -- Only top-scoring post per user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;


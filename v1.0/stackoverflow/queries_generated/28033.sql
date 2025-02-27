WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS PopularTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tag
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        us.QuestionCount,
        us.TotalScore,
        us.TotalViews,
        us.PopularTags
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.Rank = 1 -- Latest question for each user
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerDisplayName,
    trp.OwnerReputation,
    trp.CreationDate,
    trp.Score,
    trp.QuestionCount,
    trp.TotalScore,
    trp.TotalViews,
    trp.PopularTags
FROM 
    TopRankedPosts trp
WHERE 
    trp.Score > 10 -- Only showing questions with a significant score
ORDER BY 
    trp.CreationDate DESC
LIMIT 50; -- Limit results to the latest 50 questions

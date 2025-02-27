WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(pt.Name, ''), 'Uncategorized') AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, pt.Name
), UserRanking AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(rp.Score) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), AnswerSummary AS (
    SELECT 
        p.ParentId,
        COUNT(*) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2
    GROUP BY 
        p.ParentId
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalScore,
    u.ScoreRank,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.PostType,
    rp.Tags,
    COALESCE(asum.AnswerCount, 0) AS RelatedAnswerCount,
    COALESCE(asum.TotalScore, 0) AS RelatedAnswerScore
FROM 
    UserRanking u
JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    AnswerSummary asum ON rp.PostId = asum.ParentId
WHERE 
    u.Reputation > 100
ORDER BY 
    u.ScoreRank, rp.CreationDate DESC;

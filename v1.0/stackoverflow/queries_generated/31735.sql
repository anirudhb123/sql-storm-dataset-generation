WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- edit title, body, or tags
    GROUP BY 
        ph.PostId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent,
        COUNT(DISTINCT v.PostId) AS TotalVotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id
),

FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.TagsList,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ph.LastEditDate,
        ua.UserId,
        ua.DisplayName AS UserDisplayName,
        ua.Reputation,
        ua.TotalBountySpent,
        ua.TotalVotesGiven,
        CASE 
            WHEN rp.RankByScore <= 10 THEN 'Top Rated' 
            WHEN rp.RankByViewCount <= 10 THEN 'Most Viewed'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistorySummary ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        UserActivity ua ON ua.TotalVotesGiven > 5
)

SELECT 
    f.* 
FROM 
    FinalOutput f
WHERE 
    f.EditCount > 2 
    OR (f.TotalBountySpent > 0 AND f.Reputation > 100)
ORDER BY 
    f.Score DESC, f.ViewCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        STRING_AGG(ph.Comment, '; ') AS HistoryComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.Tags,
    ur.DisplayName AS Author,
    ur.Reputation,
    ur.ReputationRank,
    phs.HistoryCount,
    phs.HistoryComments
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.UserPostRank <= 5 -- Top 5 posts per user
ORDER BY 
    ur.Reputation DESC, 
    rp.Score DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) FILTER (WHERE c.Score > 0) AS PositiveCommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId, p.Score, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),

ModeratedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.PostTypeId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.Comment
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Posts that were closed or reopened
)

SELECT 
    rp.PostID,
    rp.Title,
    rp.AnswerCount,
    COALESCE(rp.PositiveCommentCount, 0) AS PositiveCommentCount,
    ur.Reputation AS UserReputation,
    ur.DisplayName AS UserDisplayName,
    COALESCE(mh.HistoryDate, NULL) AS LastActionDate,
    mh.Comment AS LastActionComment,
    CASE 
        WHEN rp.AnswerCount > 0 THEN (rp.Score * 100.0) / NULLIF(rp.AnswerCount, 0) 
        ELSE NULL 
    END AS ScorePerAnswer,
    ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.AnswerCount DESC) AS OverallRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON ur.UserID = u.Id
LEFT JOIN 
    ModeratedPosts mh ON mh.PostID = rp.PostID
WHERE 
    (ur.Reputation > 500 OR ur.TotalBadgeClass > 2) 
    AND rp.UserPostRank = 1 -- Only take the latest posts per user
ORDER BY 
    OverallRank DESC
LIMIT 100;

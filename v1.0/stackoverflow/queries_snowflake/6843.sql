
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01'::DATE - INTERVAL '1 YEAR'
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentCounts AS (
    SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId
),
AnswerCounts AS (
    SELECT ParentId AS PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId
),
BadgeCounts AS (
    SELECT UserId, COUNT(DISTINCT Id) AS BadgeCount FROM Badges GROUP BY UserId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerName,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(ac.AnswerCount, 0) AS AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    TopRankedPosts PD
LEFT JOIN 
    CommentCounts pc ON PD.PostId = pc.PostId
LEFT JOIN 
    AnswerCounts ac ON PD.PostId = ac.PostId
LEFT JOIN 
    BadgeCounts b ON PD.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    Votes v ON PD.PostId = v.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.OwnerName, pc.CommentCount, ac.AnswerCount, b.BadgeCount
ORDER BY 
    b.BadgeCount DESC, pc.CommentCount DESC;

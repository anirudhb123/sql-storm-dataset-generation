
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS OwnerPostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0, @current_user := NULL) AS init
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    rp.VoteCount,
    ur.DisplayName AS OwnerName,
    ur.Reputation AS OwnerReputation,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.OwnerPostRank = 1
ORDER BY 
    rp.VoteCount DESC, rp.AnswerCount DESC
LIMIT 100;

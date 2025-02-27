
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT p.Id, STRING_SPLIT(p.Tags, '>') AS TagArray FROM Posts p) AS ta ON TRUE
    LEFT JOIN 
        JSON_TABLE(ta.TagArray, '$[*]' COLUMNS(TagName VARCHAR(255) PATH '$')) AS t ON TRUE 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
), 

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR '; ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

RecentActivity AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AnswerCount,
    rp.NetVotes,
    rb.BadgeCount,
    ra.CommentCount,
    ra.LastCommentDate,
    rp.TagsList,
    CASE 
        WHEN ra.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivityStatus,
    CASE 
        WHEN rp.OwnerPostRank = 1 AND rb.BadgeCount > 0 THEN 'Active Top User with Badges'
        ELSE 'Regular Post'
    END AS UserPostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.Score > 10
ORDER BY 
    rp.Score DESC, rp.PostId
LIMIT 50;

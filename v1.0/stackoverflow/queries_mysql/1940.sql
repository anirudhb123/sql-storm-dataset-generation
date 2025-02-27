mysql
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(MAX(CASE WHEN v.VoteTypeId = 2 THEN v.VoteTypeId END), 0) AS Upvotes,
        COALESCE(MAX(CASE WHEN v.VoteTypeId = 3 THEN v.VoteTypeId END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRank
    FROM 
        PostStats ps
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Upvotes,
        rp.Downvotes,
        rp.CommentCount,
        rp.PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 100
)
SELECT 
    fp.Title,
    fp.Score,
    fp.Upvotes - fp.Downvotes AS NetVotes,
    fp.CommentCount,
    COALESCE((SELECT GROUP_CONCAT(CONCAT(u.DisplayName, ' (', b.Name, ')') SEPARATOR ', ')
               FROM Badges b 
               JOIN Users u ON u.Id = b.UserId
               WHERE u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)), 'No Badges') AS UserBadges
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC;

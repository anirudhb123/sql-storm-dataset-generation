WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id AND PostTypeId = 1) AS QuestionCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 AND
        u.CreationDate < (CURRENT_TIMESTAMP - INTERVAL '1 year')
)
SELECT 
    fu.DisplayName,
    fu.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest Post'
        WHEN rp.Rank <= 3 THEN 'Top 3 Recent Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    FilteredUsers fu
INNER JOIN 
    RankedPosts rp ON fu.UserId = rp.OwnerUserId
WHERE 
    rp.Upvotes > rp.Downvotes
ORDER BY 
    fu.Reputation DESC, rp.CreationDate DESC
LIMIT 50;

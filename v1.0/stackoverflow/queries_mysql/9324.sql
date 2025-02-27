
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.VoteTypeId END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.VoteTypeId END) AS DownVoteCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY ps.UpVoteCount DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY ps.CommentCount DESC) AS CommentRank
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.ViewRank <= 10 THEN 'Top Viewed'
        WHEN tp.UpVoteRank <= 10 THEN 'Top Upvoted'
        WHEN tp.CommentRank <= 10 THEN 'Top Commented'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewRank, tp.UpVoteRank, tp.CommentRank;

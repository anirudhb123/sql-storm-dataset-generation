WITH RecursiveTopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation >= 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        Votes v ON u.Id = v.UserId
    INNER JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        Level < 5 AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        pt.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    INNER JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
    WHERE 
        pht.Name = 'Post Closed'
),
TopPostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        cr.CloseReason,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRanking
    FROM 
        PostStats ps
    LEFT JOIN 
        CloseReasons cr ON ps.PostId = cr.PostId
    WHERE 
        ps.UserPostRank = 1 -- Only top post of each user
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    tpd.Title AS TopPostTitle,
    tpd.CreationDate,
    tpd.CommentCount,
    tpd.UpvoteCount,
    tpd.DownvoteCount,
    tpd.CloseReason
FROM 
    RecursiveTopUsers u
INNER JOIN 
    TopPostDetails tpd ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tpd.PostId)
WHERE 
    tpd.PostRanking <= 10 -- Top 10 posts
ORDER BY 
    u.Reputation DESC, tpd.UpvoteCount DESC;

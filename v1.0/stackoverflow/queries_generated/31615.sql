WITH RecursivePostHistory AS (
    SELECT 
        Ph.PostId,
        Ph.CreationDate,
        Ph.UserId,
        Ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS rn
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen actions
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
    HAVING 
        COUNT(DISTINCT c.Id) > 5  -- Filter for posts with more than 5 comments
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN r.PostId IS NOT NULL THEN 'Has Post History'
            ELSE 'No Post History'
        END AS PostHistoryStatus
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostHistory r ON u.Id = r.UserId
    WHERE 
        u.Reputation > 100  -- Choose users with reputation greater than 100
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    ur.UserId,
    ur.Reputation,
    ur.PostHistoryStatus
FROM 
    TopPosts tp
LEFT JOIN 
    Users ur ON ur.Id IN (
        SELECT UserId 
        FROM Comments c 
        WHERE c.PostId = tp.PostId
    )
ORDER BY 
    tp.ViewCount DESC,
    tp.CommentCount DESC;

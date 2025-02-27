WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        CAST(p.Title AS VARCHAR(4000)) AS FullTitle,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        CAST(CONCAT(rph.FullTitle, ' -> ', p.Title) AS VARCHAR(4000)) AS FullTitle,
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostSummaries AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount, -- Upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount, -- Downvotes
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseCount,
        ps.ReopenCount,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.UpVoteCount DESC) AS UpVoteRank
    FROM 
        PostSummaries ps
)
SELECT 
    T.UserId,
    U.DisplayName,
    PP.FullTitle,
    PP.Level,
    TP.CommentCount,
    TP.UpVoteCount,
    TP.DownVoteCount,
    TP.CloseCount,
    TP.ReopenCount,
    R.Reputation
FROM 
    TopPosts TP
JOIN 
    RecursivePostHierarchy PP ON TP.PostId = PP.Id
JOIN 
    Users U ON TP.OwnerUserId = U.Id
JOIN 
    UserReputation R ON U.Id = R.UserId
WHERE 
    PP.Level <= 3
    AND TP.UpVoteCount > 5
ORDER BY 
    R.Rank, TP.CommentCount DESC;

WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.ParentId,
        rp.Level + 1
    FROM
        Posts a
    INNER JOIN RecursivePostHierarchy rp ON a.ParentId = rp.PostID
),

CommentsPerPost AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM
        Comments c
    GROUP BY
        c.PostId
),

PostVotes AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),

PostsSummary AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(cp.CommentCount, 0) AS Comments,
        COALESCE(cp.PositiveComments, 0) AS PositiveComments,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.TotalVotes, 0) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN CommentsPerPost cp ON p.Id = cp.PostId
    LEFT JOIN PostVotes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only questions with positive score
),

RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.CreationDate DESC) AS PostRank,
        DENSE_RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.ViewCount DESC) AS UserViewRank
    FROM 
        PostsSummary ps
),

TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE PostRank <= 10
)

SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Comments,
    p.PositiveComments,
    p.UpVotes,
    p.DownVotes,
    pah.Level AS AnswerLevel,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    TopPosts p
LEFT JOIN RecursivePostHierarchy pah ON p.Id = pah.PostID
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY 
    p.CreatedDate DESC;

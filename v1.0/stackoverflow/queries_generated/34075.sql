WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        r.Level + 1,
        CAST(r.Path + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation,
    ur.ReputationRank,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.AllComments, 'No comments') AS AllComments,
    COALESCE(vs.UpVotes, 0) AS UpVoteCount,
    COALESCE(vs.DownVotes, 0) AS DownVoteCount,
    r.Path,
    r.Level
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    Users ur ON ur.Id = r.OwnerUserId
LEFT JOIN 
    PostComments pc ON pc.PostId = r.PostId
LEFT JOIN 
    VotesSummary vs ON vs.PostId = r.PostId
WHERE 
    ur.Reputation IS NOT NULL
ORDER BY 
    r.Level, r.CreationDate DESC;

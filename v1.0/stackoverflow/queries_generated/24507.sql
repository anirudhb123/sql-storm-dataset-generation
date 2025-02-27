WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(v.CreationDate) OVER (PARTITION BY p.Id) AS LastVoteDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.Score IS NOT NULL
        AND p.ViewCount IS NOT NULL
),

FlaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        rp.CommentCount,
        CASE 
            WHEN rp.Score < 0 AND (rp.LastVoteDate IS NULL OR rp.LastVoteDate < NOW() - INTERVAL '7 days') THEN 'Flagged: Negative Score & Inactive'
            ELSE 'Normal'
        END AS Status
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.ScoreRank,
    fp.CommentCount,
    fp.Status,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    JSON_AGG(DISTINCT JSON_BUILD_OBJECT('VoteType', vt.Name, 'User', u.DisplayName)) AS VoteDetails
FROM 
    FlaggedPosts fp
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    Users u ON v.UserId = u.Id
LEFT JOIN 
    LATERAL STRING_TO_ARRAY(fp.Title, ' ') AS words ON TRUE 
LEFT JOIN 
    PostLinks pl ON fp.PostId = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.ViewCount, fp.ScoreRank, fp.CommentCount, fp.Status
HAVING 
    COUNT(DISTINCT t.Id) >= 2 OR fp.Status LIKE 'Flagged%'
ORDER BY 
    fp.ScoreRank ASC, fp.CreationDate DESC;

WITH RecursiveVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.UserId
)

SELECT 
    p.Title,
    (SELECT COUNT(*) FROM RecursiveVotes rv WHERE rv.PostId = p.Id) AS UniqueVoterCount,
    COALESCE(SUM(CASE WHEN rv.VoteCount > 2 THEN 1 ELSE 0 END), 0) AS MultipleVotingUsers
FROM 
    Posts p
LEFT JOIN 
    RecursiveVotes rv ON p.Id = rv.PostId
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Title
HAVING 
    COALESCE(SUM(rv.VoteCount), 0) > 3
ORDER BY 
    UniqueVoterCount DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS Badge,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1
    WHERE 
        rp.UserPostRank = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.Badge,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score' 
        WHEN pd.Score >= 10 THEN 'High Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.Score DESC
LIMIT 100;

WITH RecentVotes AS (
    SELECT 
        v.PostId, 
        v.CreationDate,
        v.UserId,
        vt.Name AS VoteTypeName
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
),
UserVoteSummary AS (
    SELECT 
        rv.UserId,
        COUNT(rv.PostId) AS VotesCount,
        STRING_AGG(rv.VoteTypeName, ', ') AS VoteTypes
    FROM 
        RecentVotes rv
    GROUP BY 
        rv.UserId
)
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.Views,
    COALESCE(uvs.VotesCount, 0) AS TotalVotes,
    COALESCE(uvs.VoteTypes, 'No Votes') AS VoteTypesSummary
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary uvs ON u.Id = uvs.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC;

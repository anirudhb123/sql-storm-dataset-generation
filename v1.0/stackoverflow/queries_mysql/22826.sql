
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(CASE WHEN c.Score > 0 THEN 1 END) AS PositiveCommentCount,
        COUNT(CASE WHEN c.Score < 0 THEN 1 END) AS NegativeCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

RecentVoteCounts AS (
    SELECT 
        Vote.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
    FROM 
        Votes Vote
    JOIN 
        VoteTypes vt ON Vote.VoteTypeId = vt.Id
    WHERE 
        Vote.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        Vote.PostId
),

FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        rp.PostRank,
        COALESCE(rvc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(rvc.DownVoteCount, 0) AS DownVoteCount,
        rp.PositiveCommentCount,
        rp.NegativeCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVoteCounts rvc ON rp.PostId = rvc.PostId
    WHERE 
        (rp.Score > 10 OR rp.PositiveCommentCount > 5)
        AND (rvc.DownVoteCount IS NULL OR rvc.UpVoteCount > rvc.DownVoteCount)
)

SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.Score,
    fps.UpVoteCount,
    fps.DownVoteCount,
    fps.PositiveCommentCount,
    fps.NegativeCommentCount
FROM 
    FinalPostStats fps
JOIN 
    Users u ON fps.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id 
WHERE 
    fps.PostRank <= 3 
    AND (b.Class IN (1, 2) OR b.Id IS NULL)  
ORDER BY 
    fps.Score DESC, fps.CreationDate DESC;

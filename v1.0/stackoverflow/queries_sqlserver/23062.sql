
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotesCount
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate > DATEADD(DAY, -30, '2024-10-01')
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteTotal,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate > DATEADD(DAY, -14, '2024-10-01')
    GROUP BY 
        v.PostId
), FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 AND 
        b.Date >= DATEADD(YEAR, -1, '2024-10-01')
    GROUP BY 
        b.UserId
), Final AS (
    SELECT 
        rp.PostId,
        rp.Title, 
        rp.Score,
        rp.UserPostRank,
        rv.VoteTotal,
        fb.BadgeCount,
        CASE 
            WHEN rv.LastVoteDate IS NULL THEN 'No recent votes'
            ELSE 'Recently voted'
        END AS VotingStatus,
        CASE 
            WHEN rp.UpVotesCount - rp.DownVotesCount > 0 THEN 'Positive' 
            ELSE 'Negative' 
        END AS ScoreStatus
    FROM 
        RankedPosts rp
        LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
        LEFT JOIN FilteredBadges fb ON rp.AcceptedAnswerId = fb.UserId
    WHERE 
        rp.UserPostRank <= 5 AND 
        (fb.BadgeCount IS NULL OR fb.BadgeCount > 0) 
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.VoteTotal,
    f.VotingStatus,
    f.ScoreStatus
FROM 
    Final f
WHERE 
    f.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate > DATEADD(DAY, -30, '2024-10-01'))
ORDER BY 
    f.Score DESC, f.VoteTotal DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

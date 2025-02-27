WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseVoteCount,
        MIN(ph.CreationDate) AS FirstCloseVoteDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ph.CloseVoteCount, 0) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPostHistory ph ON p.OwnerUserId = ph.UserId
    WHERE 
        p.Score > 0 AND
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 5
),
UserRanking AS (
    SELECT 
        u.DisplayName,
        ur.UserId,
        ROW_NUMBER() OVER (ORDER BY ur.PostCount DESC, ur.UpVotes DESC, ur.DownVotes ASC) AS Rank
    FROM 
        UserVoteCounts ur
    JOIN 
        Users u ON ur.UserId = u.Id
),
PostRanking AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CloseVoteCount,
        RANK() OVER (ORDER BY ps.Score DESC, ps.CloseVoteCount ASC) AS PostRank
    FROM 
        PostStatistics ps
)
SELECT 
    ur.Rank AS UserRank,
    ur.DisplayName,
    ur.UpVotes,
    ur.DownVotes,
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.Score,
    pr.CloseVoteCount,
    CASE WHEN pr.CloseVoteCount > 0 THEN 'Closed' ELSE 'Open' END AS PostStatus
FROM 
    UserRanking ur
JOIN 
    PostRanking pr ON ur.PostCount > 5
ORDER BY 
    ur.Rank, pr.PostRank;

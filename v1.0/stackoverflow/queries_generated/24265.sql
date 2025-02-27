WITH ActiveUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        u.LastAccessDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    GROUP BY u.Id
),

ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

RankedPosts AS (
    SELECT 
        pd.PostId, 
        pd.Title, 
        pd.CommentCount,
        pd.VoteCount,
        pd.UpVotes,
        pd.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pd.CommentCount ORDER BY pd.UpVotes DESC) as RankByComments,
        RANK() OVER (ORDER BY pd.VoteCount DESC) AS VoteRank
    FROM PostDetails pd
    WHERE pd.CommentCount > 0
),

FinalOutput AS (
    SELECT 
        au.DisplayName AS UserName,
        au.Reputation,
        pp.Title AS PostTitle,
        pp.CommentCount,
        pp.UpVotes,
        pp.DownVotes,
        cp.ClosedDate,
        cp.ClosedBy,
        cp.CloseReason
    FROM ActiveUsers au
    JOIN RankedPosts pp ON au.Id = pp.PostId
    LEFT JOIN ClosedPosts cp ON pp.PostId = cp.PostId 
    WHERE au.PostCount > 5 
      AND pp.RankByComments <= 3 
      AND (pp.UpVotes - pp.DownVotes) > 10
)

SELECT * 
FROM FinalOutput
ORDER BY Reputation DESC, ClosedDate DESC NULLS LAST;

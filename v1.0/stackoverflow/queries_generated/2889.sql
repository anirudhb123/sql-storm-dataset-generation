WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 10), 0) AS DeletedVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostAggregate AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
DeletedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS DeletedDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 12)
),
FinalResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(p.TotalPosts, 0) AS TotalPosts,
        COALESCE(p.Questions, 0) AS Questions,
        COALESCE(p.Answers, 0) AS Answers,
        COALESCE(p.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(us.UpVotes - us.DownVotes, 0) AS NetVotes,
        COALESCE(us.DeletedVotes, 0) AS DeletedVotes,
        COALESCE(dp.DeletedDate, 'No Deletions') AS LastDeletedPost,
        COALESCE(dp.CloseReason, 'N/A') AS LastCloseReason
    FROM 
        UserScore us
    FULL OUTER JOIN 
        PostAggregate p ON us.UserId = p.OwnerUserId
    LEFT JOIN 
        DeletedPostInfo dp ON us.UserId = dp.UserId
)

SELECT * 
FROM FinalResults
WHERE NetVotes > 10 
ORDER BY TotalPosts DESC, AverageScore DESC;

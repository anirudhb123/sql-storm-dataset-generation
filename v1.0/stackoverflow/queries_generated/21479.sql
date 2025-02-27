WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBountySpent,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AverageScore,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        t.Id, t.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBountySpent,
    ua.ReputationRank,
    ts.TagName,
    ts.PostCount,
    COALESCE(ts.AverageScore, 0) AS AverageScore,
    phs.ChangeTypes,
    phs.FirstChangeDate,
    phs.LastChangeDate
FROM 
    UserActivity ua
LEFT JOIN 
    TagStats ts ON ua.TotalPosts > 0 AND ts.PostCount > 0
LEFT JOIN 
    PostHistorySummary phs ON ua.TotalPosts > 0 
WHERE 
    ua.ReputationRank <= 10 
    OR ua.TotalBountySpent > 100 
ORDER BY 
    ua.ReputationRank, ts.PostCount DESC, phs.LastChangeDate DESC;

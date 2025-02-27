WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT v.PostId) DESC) AS VoteRank
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
TagPopularity AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) -- Title, Body edits and Close
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id, ph.UserDisplayName
)

SELECT 
    u.DisplayName AS UserName,
    ust.UserId,
    ust.TotalVotes,
    ust.UpVotes,
    ust.DownVotes,
    tp.TagName,
    tp.PostCount,
    tp.TotalViews,
    COALESCE(cp.ClosedDate, 'Never Closed') AS LastClosedDate,
    COALESCE(cp.ClosedBy, 'N/A') AS ClosedBy,
    CASE 
        WHEN ust.DownVotes > ust.UpVotes THEN 'More Downvotes'
        ELSE 'More Upvotes'
    END AS VoteBalance,
    CONCAT('Total Vote Difference: ', (ust.UpVotes - ust.DownVotes)) AS VoteDifference,
    CASE 
        WHEN ust.TotalVotes = 0 THEN 'No Activity'
        WHEN ust.VoteRank <= 10 THEN 'Top 10 Voter'
        ELSE 'Regular Voter'
    END AS UserVotingTier,
    phd.LastEdited AS LastEditDate
FROM 
    UserVoteStats ust
LEFT JOIN 
    TagPopularity tp ON ust.UserId = tp.TagId
LEFT JOIN 
    ClosedPosts cp ON ust.UserId = cp.PostId
LEFT JOIN 
    PostHistoryDetails phd ON ust.UserId = phd.PostId
INNER JOIN 
    Users u ON u.Id = ust.UserId
WHERE 
    tp.PostCount >= 5 AND -- Tags with at least 5 posts
    u.Reputation >= 1000 -- Users with a reputation of at least 1000
ORDER BY 
    ust.TotalVotes DESC, 
    tp.TotalViews DESC
LIMIT 50;

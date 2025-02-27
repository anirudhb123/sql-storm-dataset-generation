WITH RecursivePostScore AS (
    SELECT
        p.Id AS PostId,
        p.Score AS InitialScore,
        COALESCE(vs.TotalUpVotes, 0) - COALESCE(vs.TotalDownVotes, 0) AS NetVotes,
        p.OwnerUserId,
        0 AS Level
    FROM Posts p
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    WHERE p.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT
        p.Id AS PostId,
        p.Score AS InitialScore,
        COALESCE(vs.TotalUpVotes, 0) - COALESCE(vs.TotalDownVotes, 0) AS NetVotes,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    JOIN RecursivePostScore r ON r.PostId = p.ParentId
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
),
AggregatedData AS (
    SELECT
        rp.PostId,
        rp.InitialScore,
        rp.NetVotes,
        u.Reputation AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.InitialScore + rp.NetVotes DESC) AS Rank,
        ROW_NUMBER() OVER (ORDER BY rp.InitialScore + rp.NetVotes DESC) AS OverallRank
    FROM RecursivePostScore rp
    JOIN Users u ON rp.OwnerUserId = u.Id
)
SELECT
    ad.PostId,
    ad.InitialScore,
    ad.NetVotes,
    ad.UserReputation,
    ad.Rank,
    ad.OverallRank,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM AggregatedData ad
LEFT JOIN Posts p ON ad.PostId = p.Id
LEFT JOIN (
    SELECT
        pt.PostId,
        STRING_AGG(t.TagName, ', ') AS TagName
    FROM PostsTags pt
    JOIN Tags t ON pt.TagId = t.Id
    GROUP BY pt.PostId
) t ON p.Id = t.PostId
WHERE ad.OverallRank <= 100  -- Top 100 posts
GROUP BY ad.PostId, ad.InitialScore, ad.NetVotes, ad.UserReputation, ad.Rank, ad.OverallRank
ORDER BY ad.OverallRank;

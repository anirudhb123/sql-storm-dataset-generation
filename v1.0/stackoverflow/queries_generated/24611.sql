WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

VoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.CreationDate > (NOW() - INTERVAL '30 days') THEN (CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) ELSE 0 END) AS RecentVoteImpact
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

MostVotedPosts AS (
    SELECT 
        rp.*,
        vs.Upvotes,
        vs.Downvotes,
        (rs.Upvotes - rs.Downvotes) AS NetVotes,
        COALESCE(NULLIF(vs.RecentVoteImpact, 0), NULL) AS AdjustedImpact
    FROM 
        RankedPosts rp
    LEFT JOIN 
        VoteSummary vs ON rp.PostId = vs.PostId
    WHERE 
        rp.PostRank = 1
),

OpenPostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopen actions
)

SELECT 
    mp.Title,
    mp.CreationDate,
    mp.Score,
    mp.ViewCount,
    mp.Upvotes,
    mp.Downvotes,
    mp.NetVotes,
    ph.UserId AS LastActionUser,
    ph.CreationDate AS LastActionDate,
    CASE 
        WHEN mp.AdjustedImpact IS NOT NULL THEN 'Has Recent Voting Impact'
        ELSE 'No Recent Voting Impact'
    END AS ImpactStatus
FROM 
    MostVotedPosts mp
LEFT JOIN 
    OpenPostHistory ph ON mp.PostId = ph.PostId
WHERE 
    mp.NetVotes > 0 AND 
    (ph.CreationDate IS NULL OR ph.CreationDate >= NOW() - INTERVAL '30 days')
ORDER BY 
    mp.NetVotes DESC, 
    mp.ViewCount DESC;

WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        ts.*,
        RANK() OVER (ORDER BY ts.TotalScore DESC) AS TagRank
    FROM 
        TagStats ts
)

SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalScore,
    CASE 
        WHEN tt.TagRank <= 5 THEN 'Top Tag'
        ELSE 'Other Tag'
    END AS TagCategory
FROM 
    TopTags tt
WHERE 
    tt.PostCount > 10 -- Only tags with more than 10 related posts
ORDER BY 
    tt.TotalScore DESC;

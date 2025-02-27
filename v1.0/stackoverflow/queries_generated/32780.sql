WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.CreationDate,
        a.OwnerUserId,
        a.Score,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    WHERE 
        q.PostTypeId = 1  -- Join with Answers
),
RankedPosts AS (
    SELECT 
        ph.PostId,
        ph.PostTitle,
        ph.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ph.Score,
        RANK() OVER (PARTITION BY ph.OwnerUserId ORDER BY ph.Score DESC) AS ScoreRank
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Users u ON ph.OwnerUserId = u.Id
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS TotalPosts
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000  -- Only consider users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pu.DisplayName,
    pu.TotalScore,
    pu.TotalPosts,
    pvs.PostId,
    pvs.UpVotes,
    pvs.DownVotes,
    CASE 
        WHEN pvs.UpVotes > pvs.DownVotes THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    TopUsers pu
JOIN 
    PostVoteSummary pvs ON pu.UserId = pvs.PostId  -- Assuming PostId was the OwnerUserId
ORDER BY 
    pu.TotalScore DESC, pu.TotalPosts DESC 
FETCH FIRST 10 ROWS ONLY;

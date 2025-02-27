WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.Score > 0 
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened' 
            ELSE CAST(ph.CreationDate AS varchar) 
        END, ', ') AS PostHistory,
        COUNT(DISTINCT ph.Id) AS RevisionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(h.PostHistory, 'No history') AS PostHistory,
    COALESCE(h.RevisionCount, 0) AS RevisionCount,
    RANK() OVER (ORDER BY COALESCE(v.VoteCount, 0) DESC) AS VoteRank
FROM 
    RankedPosts p
LEFT JOIN 
    RecentVotes v ON p.PostId = v.PostId
LEFT JOIN 
    PostHistoryDetails h ON p.PostId = h.PostId
WHERE 
    p.rn = 1 -- Only the most recent question per user
ORDER BY 
    VoteRank, p.CreationDate DESC;

-- Including an outer join with a potential NULL logic predicate
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(p.PostCount, 0) AS PostCount,
    CASE WHEN p.PostCount IS NULL THEN 'No Posts Yet' ELSE 'Active' END AS UserStatus
FROM 
    Users u
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM 
        Posts 
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year' -- only consider recent posts
    GROUP BY 
        OwnerUserId
) p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 1000 -- High reputation users
ORDER BY 
    u.Reputation DESC;

-- An additional subquery to check for null related post links
SELECT 
    pl.PostId,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostLinks WHERE RelatedPostId = pl.PostId) 
        THEN 'Linked' 
        ELSE 'No Links Found' 
    END AS LinkStatus
FROM 
    PostLinks pl
LEFT JOIN 
    Posts p ON pl.PostId = p.Id
WHERE 
    p.CreationDate < NOW() - INTERVAL '6 months';

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
),
PostUpdates AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS UpdateDate,
        p.Title AS UpdatedTitle,
        pt.Name AS PostType,
        ph.UserDisplayName AS LastUpdatedBy
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' 
        AND pt.Name IN ('Edit Title', 'Edit Body')
),
AggregatedPostData AS (
    SELECT
        p.PostId,
        MAX(p.UpdateDate) AS MostRecentUpdate,
        COUNT(DISTINCT pm.UserId) AS TotalEditors,
        STRING_AGG(DISTINCT pm.UserDisplayName, ', ') AS EditorsList
    FROM 
        PostUpdates p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.PostId
    LEFT JOIN 
        Users pm ON ph.UserId = pm.Id
    GROUP BY 
        p.PostId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment 
            ELSE 'No reason provided' END) AS ClosureComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserRank,
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.UpVotes,
    p.DownVotes,
    apd.MostRecentUpdate,
    apd.TotalEditors,
    apd.EditorsList,
    COALESCE(cpr.ClosureComments, ARRAY['No closures']) AS ClosureReasons
FROM 
    RankedPosts p
JOIN 
    TopUsers u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    AggregatedPostData apd ON p.PostId = apd.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON p.PostId = cpr.PostId
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank, p.Score DESC, p.CreationDate DESC
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;

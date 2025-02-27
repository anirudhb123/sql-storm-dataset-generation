WITH RecursivePostHistory AS (
    SELECT
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn,
        ph.RevisionGUID,
        ph.Text
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12) -- Considering Closed, Reopened, and Deleted posts
),
AggregatedVotes AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountyGained
    FROM
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE
        v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBountyGained DESC
    LIMIT 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    v.TotalUpVotes,
    v.TotalDownVotes,
    v.TotalVotes,
    ph.Comment AS LastActionComment,
    u.DisplayName AS LastEditorDisplayName,
    pt.TagsList,
    CASE 
        WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Closed or Deleted'
        ELSE 'Open'
    END AS CurrentStatus,
    COALESCE(b.TotalBountyGained, 0) AS TotalBountyGained
FROM 
    Posts p
LEFT JOIN 
    AggregatedVotes v ON p.Id = v.PostId
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1 
LEFT JOIN 
    Users u ON p.LastEditorUserId = u.Id 
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId 
LEFT JOIN 
    TopUsers b ON p.OwnerUserId = b.UserId 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' 
    AND p.ViewCount > 100
ORDER BY 
    p.CreationDate DESC;

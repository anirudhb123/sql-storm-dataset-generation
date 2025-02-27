WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),

PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 -- Only tags with more than 10 associated posts
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        pt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, pt.Name
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    STRING_AGG(pt.TagName, ', ') AS PopularTags,
    cp.LastClosedDate,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 5
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts of each type
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, 
    rp.LastActivityDate, rp.Score, rp.ViewCount, 
    rp.OwnerDisplayName, cp.LastClosedDate, cp.CloseReason
ORDER BY 
    rp.LastActivityDate DESC;

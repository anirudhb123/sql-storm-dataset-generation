WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rph ON a.ParentId = rph.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers
),
AggregatedPostStats AS (
    SELECT 
        rph.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(b.Class) AS HighestBadgeClass   -- Most significant badge class per user
    FROM 
        RecursivePostHierarchy rph
    LEFT JOIN 
        Comments c ON rph.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rph.PostId = v.PostId
    LEFT JOIN 
        Badges b ON rph.PostId = b.UserId
    GROUP BY 
        rph.PostId
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 OR p.PostTypeId = 2 -- Include only Questions & Answers
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    a.PostId,
    a.CommentCount,
    a.TotalBounty,
    a.UpVotes,
    a.DownVotes,
    a.HighestBadgeClass,
    COALESCE(pt.Title, 'N/A') AS PostTitle,
    COALESCE(pt.Tags, 'No Tags') AS AssociatedTags,
    CASE 
        WHEN a.UpVotes > a.DownVotes THEN 'Positive' 
        WHEN a.UpVotes < a.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    AggregatedPostStats a
LEFT JOIN 
    PostWithTags pt ON a.PostId = pt.PostId
ORDER BY 
    a.TotalBounty DESC, a.CommentCount DESC;

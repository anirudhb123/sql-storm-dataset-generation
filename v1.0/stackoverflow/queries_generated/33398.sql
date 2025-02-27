WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.PostTypeId,
        a.CreationDate,
        rp.Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursivePostHierarchy rp ON q.Id = rp.PostId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        vt.Name AS VoteType,
        v.CreationDate
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
),
PostMetrics AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS UserVoteRank
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    LEFT JOIN 
        RecentVotes v ON ph.PostId = v.PostId
    LEFT JOIN 
        Badges b ON ph.OwnerUserId = b.UserId
    GROUP BY 
        ph.PostId
),
PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        pm.CommentCount,
        pm.VoteCount,
        pm.UpVotes,
        pm.DownVotes,
        COUNT(DISTINCT t.Id) AS RelatedTagCount,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS LinkCount
    FROM 
        Posts p
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    LEFT JOIN 
        Tags t ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, pm.CommentCount, pm.VoteCount, pm.UpVotes, pm.DownVotes
),
FinalResults AS (
    SELECT 
        pa.*,
        CASE 
            WHEN pa.UpVotes > pa.DownVotes THEN 'Positive' 
            WHEN pa.UpVotes < pa.DownVotes THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment,
        ROW_NUMBER() OVER (ORDER BY pa.UpVotes DESC, pa.DownVotes ASC) AS OverallRank
    FROM 
        PostAggregates pa
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CommentCount,
    f.VoteCount,
    f.UpVotes,
    f.DownVotes,
    f.RelatedTagCount,
    f.LinkCount,
    f.Sentiment,
    f.OverallRank
FROM 
    FinalResults f
WHERE 
    f.VoteCount > 10  -- Filter for popular posts
ORDER BY 
    f.OverallRank;

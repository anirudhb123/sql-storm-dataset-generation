WITH RECURSIVE TagHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(STRING_AGG(DISTINCT pt.Name, ', '), 'No Tags') AS TagNames
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT 
                     TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))) ) AS Name
                 ) AS TagList ON TRUE
    LEFT JOIN 
        Tags tg ON TagList.Name = tg.TagName
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Last 30 days
    GROUP BY 
        p.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,  -- Upvotes
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount  -- Downvotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'  -- Last 30 days
    GROUP BY 
        v.PostId
),
Summary AS (
    SELECT 
        th.PostId,
        th.Title,
        th.CreationDate,
        th.Score,
        th.TagNames,
        th.OwnerDisplayName,
        COALESCE(rv.UpVotesCount, 0) AS UpVotes,
        COALESCE(rv.DownVotesCount, 0) AS DownVotes
    FROM 
        TagHierarchy th
    LEFT JOIN 
        RecentVotes rv ON th.PostId = rv.PostId
)
SELECT 
    s.PostId,
    s.Title,
    s.CreationDate,
    s.Score,
    s.TagNames,
    s.OwnerDisplayName,
    s.UpVotes,
    s.DownVotes,
    CASE 
        WHEN s.Score > 10 THEN 'Highly Engaged' 
        WHEN s.Score BETWEEN 1 AND 10 THEN 'Moderately Engaged' 
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM 
    Summary s
ORDER BY 
    s.UpVotes DESC, s.DownVotes ASC, s.Score DESC;

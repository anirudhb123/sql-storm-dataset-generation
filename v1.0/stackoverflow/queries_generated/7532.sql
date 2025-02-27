WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10 -- Tag used in more than 10 posts
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Closed or reopened posts
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.TagName,
    ph.LastHistoryDate
FROM 
    RankedPosts rp
JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PopularTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank <= 100 -- Top 100 recent questions
ORDER BY 
    rp.CreationDate DESC, rp.UpVotes DESC;

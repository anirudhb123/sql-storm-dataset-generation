WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS TotalDownvotes,
        COALESCE(pv.UtilizedTags, '{}') AS UtilizedTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            ARRAY_AGG(DISTINCT TRIM(UNNEST(string_to_array(Tags, '><')))) AS UtilizedTags
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 -- Only consider questions
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Focus on recent posts
    GROUP BY 
        p.Id, pv.UtilizedTags
),

PostHistories AS (
    SELECT 
        post.Id AS PostId,
        pht.Name AS PostHistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory post
    JOIN 
        PostHistoryTypes pht ON post.PostHistoryTypeId = pht.Id
    GROUP BY 
        post.Id, pht.Name
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.TotalComments,
        rp.TotalUpvotes,
        rp.TotalDownvotes,
        ph.PostHistoryType,
        ph.HistoryCount,
        rp.UtilizedTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
)

SELECT 
    PostId,
    Title,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes,
    ARRAY_AGG(DISTINCT UtilizedTags) AS UtilizedTags,
    STRING_AGG(DISTINCT PostHistoryType || ': ' || HistoryCount, ', ') AS HistoryInsights
FROM 
    FinalResults
GROUP BY 
    PostId, Title, TotalComments, TotalUpvotes, TotalDownvotes
ORDER BY 
    TotalUpvotes DESC, TotalComments DESC;

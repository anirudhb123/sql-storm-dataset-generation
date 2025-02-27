WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(p.Score, 0) AS Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(pa.UserVotes, 0) AS UserVotes,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY COALESCE(p.Score, 0) DESC, COALESCE(p.ViewCount, 0) DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS PostTags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UserVotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2  -- only counting upvotes
        GROUP BY 
            PostId
    ) pa ON p.Id = pa.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, pt.Name
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, Body, Score, ViewCount, UserVotes, PostTags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- getting top 5 posts per type
)
SELECT 
    pt.Name AS PostType,
    COUNT(trp.PostId) AS TopPostCount,
    SUM(trp.Score) AS TotalScore,
    SUM(trp.ViewCount) AS TotalViews,
    AVG(trp.UserVotes) AS AvgUserVotes,
    STRING_AGG(DISTINCT unnest(trp.PostTags), ', ') AS AllTags
FROM 
    PostTypes pt
JOIN 
    TopRankedPosts trp ON pt.Id IN (SELECT DISTINCT p.PostTypeId FROM Posts p WHERE p.Id = trp.PostId)
GROUP BY 
    pt.Name
ORDER BY 
    TotalScore DESC, TopPostCount DESC;

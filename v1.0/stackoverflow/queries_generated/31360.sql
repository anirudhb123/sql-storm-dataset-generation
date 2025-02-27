WITH RecursiveTagCounts AS (
    -- CTE to count posts per tag recursively, starting with popular tags (most used)
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.Id
    ORDER BY 
        PostCount DESC
    LIMIT 10
), 
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS NumPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        LATERAL (SELECT * FROM string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[] AS tag) tg ON true
    LEFT JOIN 
        Tags t ON tg.tag = t.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(pc.ClosedDate, p.LastActivityDate) AS LatestActivity,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, -- Count of upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes -- Count of downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts pc ON p.AcceptedAnswerId = pc.Id -- Link to parent post for accepted answers
    GROUP BY 
        p.Id, pc.ClosedDate
), 
MergedPostDetails AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        COUNT(pa.PostId) AS PostCount,
        SUM(pa.Score) AS TotalScore,
        AVG(pa.ViewCount) AS AvgViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        UserPostDetails up
    LEFT JOIN 
        PostActivity pa ON up.UserId = pa.PostId
    LEFT JOIN 
        LATERAL (SELECT * FROM string_to_array(up.TagsUsed, ',') AS tag) tg ON true 
    LEFT JOIN 
        Tags t ON tg.tag = t.TagName
    GROUP BY 
        up.UserId, up.DisplayName
)
-- Final selection of enriched data
SELECT 
    mt.UserId,
    mt.DisplayName,
    mt.PostCount,
    mt.TotalScore,
    mt.AvgViewCount,
    rt.TagId,
    rt.TagName,
    rt.PostCount AS TagPostCount
FROM 
    MergedPostDetails mt
JOIN 
    RecursiveTagCounts rt ON mt.Tags ILIKE '%' || rt.TagName || '%'
ORDER BY 
    mt.TotalScore DESC, rt.PostPostCount DESC;

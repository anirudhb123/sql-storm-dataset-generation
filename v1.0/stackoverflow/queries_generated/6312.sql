WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '>') tag_arr ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_arr
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name, u.DisplayName
),
Summary AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COALESCE(SUM(Score), 0) AS TotalScore,
        COALESCE(SUM(ViewCount), 0) AS TotalViews,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViews
    FROM 
        PostDetails
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.PostType,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.Tags,
    s.TotalPosts,
    s.TotalScore,
    s.TotalViews,
    s.AvgScore,
    s.AvgViews
FROM 
    PostDetails pd, Summary s
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;

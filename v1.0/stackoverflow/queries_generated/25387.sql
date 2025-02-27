WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TrendingTags AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts created in the last 30 days
    GROUP BY 
        tag.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        ARRAY_AGG(tt.TagName) AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Unnest(string_to_array(p.Tags, '><')) AS tag_name(tag) ON true
    LEFT JOIN 
        Tags tt ON tt.TagName = tag_name.tag
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.UpVotes, rp.DownVotes
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.Tags,
    tt.PostCount AS TrendingTagPosts
FROM 
    PostDetails pd
LEFT JOIN 
    TrendingTags tt ON tt.TagName = ANY(pd.Tags)
WHERE 
    pd.Rank <= 10  -- Get top 10 ranked posts
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;

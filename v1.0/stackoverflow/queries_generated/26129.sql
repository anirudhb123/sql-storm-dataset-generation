WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, -- Assuming UpMod is represented as 2
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes -- Assuming DownMod is represented as 3
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        TagName
),
MostPopularTags AS (
    SELECT 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 5 -- Get tags with more than 5 posts
),
RecentPosts AS (
    SELECT 
        pd.PostId, 
        pd.Title, 
        pd.OwnerDisplayName, 
        pd.CommentCount, 
        pd.CreationDate,
        mt.TagName
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    JOIN 
        MostPopularTags mt ON mt.TagName = ANY(STRING_TO_ARRAY(p.Tags, '>'))
    WHERE 
        pd.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    ORDER BY 
        pd.CreationDate DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.CreationDate,
    mt.TagName,
    pd.UpVotes,
    pd.DownVotes
FROM 
    RecentPosts rp
JOIN 
    PostDetails pd ON rp.PostId = pd.PostId
ORDER BY 
    rp.CreationDate DESC, 
    rp.PostId DESC
LIMIT 100; -- Limit to the 100 most recent posts

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider only posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(LEFT(p.Tags, LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', ''))) - 1), '><')::text[]) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10  -- Only include tags with more than 10 associated posts
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        pt.Name AS PostType,
        STRING_AGG(pt2.Name, ', ') AS RelatedTags  -- Concatenate related tag names
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostsTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        Tags pt2 ON pt.TagId = pt2.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.UpVotes, rp.DownVotes, pt.Name
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.PostType,
    pd.RelatedTags,
    COUNT(DISTINCT b.Id) AS BadgeCount  -- Count the number of badges held by the user who posted
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    pd.Rank <= 5  -- Get the top 5 highest-ranked posts for each PostType
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.CommentCount, pd.UpVotes, pd.DownVotes, pd.PostType, pd.RelatedTags
ORDER BY 
    pd.PostType, pd.UpVotes DESC;

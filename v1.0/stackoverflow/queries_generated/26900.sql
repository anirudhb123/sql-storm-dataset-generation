WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
), 
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.OwnerDisplayName,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        pt.PostHistoryTypeId,
        ph.CreationDate AS UpdatedAt
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        rp.rn = 1 -- Get latest version of each post
)
SELECT 
    pd.PostId,
    pd.OwnerDisplayName,
    pd.Title AS QuestionTitle,
    pd.Body AS QuestionBody,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    STRING_AGG(pt.TagName, ', ') AS Tags,
    pd.UpdatedAt
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    PopularTags pt ON p.Tags LIKE '%' || pt.TagName || '%'
GROUP BY 
    pd.PostId, pd.OwnerDisplayName, pd.Title, pd.Body, 
    pd.CommentCount, pd.UpVotes, pd.DownVotes, pd.UpdatedAt
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC
LIMIT 20;

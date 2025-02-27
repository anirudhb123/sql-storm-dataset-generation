WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        u.DisplayName as OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) as CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) as UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) as DownVoteCount,
        pt.Name as PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) as PostRank
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
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.PostTypeName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    t.PostTypeName,
    (SELECT STRING_AGG(tg.TagName, ', ') 
     FROM Tags tg 
     JOIN Posts p ON tg.Id = ANY(STRING_TO_ARRAY(p.Tags, '><')::int[]) 
     WHERE p.Id = t.PostId) as Tags
FROM 
    TopPosts t
ORDER BY 
    t.UpVoteCount DESC, 
    t.CommentCount DESC;

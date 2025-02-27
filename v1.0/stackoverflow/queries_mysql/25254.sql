
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @row_number := IF(@prev_tags = p.Tags, @row_number + 1, 1) AS TagRank,
        @prev_tags := p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        (SELECT @row_number := 0, @prev_tags := '') AS r
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.CreationDate, p.Tags, u.DisplayName
), 

FilteredPosts AS (
    SELECT 
        Id,
        Title,
        Body,
        ViewCount,
        CreationDate,
        Tags,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        UpVoteCount > DownVoteCount
    AND 
        CommentCount > 5
), 

FinalRanking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ViewCount DESC, CreationDate DESC) AS PopularityRank
    FROM 
        FilteredPosts
)

SELECT 
    Id,
    Title,
    Body,
    ViewCount,
    CreationDate,
    Tags,
    OwnerDisplayName,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    PopularityRank
FROM 
    FinalRanking
WHERE 
    PopularityRank <= 10;

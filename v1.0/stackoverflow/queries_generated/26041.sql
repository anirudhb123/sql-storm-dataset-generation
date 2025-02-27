WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS VoteRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, P.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10 -- Top 10 posts by upvotes
),
TagStats AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><')))::varchar) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        TopPosts
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
)
SELECT 
    TS.TagName,
    TS.PostCount,
    COUNT(DISTINCT TP.PostId) AS RelatedPostCount,
    SUM(TP.UpVotes) AS TotalUpVotes,
    SUM(TP.CommentCount) AS TotalComments
FROM 
    TagStats TS
JOIN 
    TopPosts TP ON TS.TagName = ANY(STRING_TO_ARRAY(SUBSTRING(TP.Tags, 2, LENGTH(TP.Tags)-2), '><'))
GROUP BY 
    TS.TagName, TS.PostCount
ORDER BY 
    TotalUpVotes DESC, TotalComments DESC;

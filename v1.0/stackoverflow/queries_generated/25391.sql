WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(T.Id) AS TagCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    WHERE 
        P.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        P.Id, P.Title
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes, -- Calculate UpVotes
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes, -- Calculate DownVotes
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.ViewCount,
        TC.TagCount,
        TC.Tags
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        PostTagCounts TC ON TC.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        P.Id, TC.TagCount, TC.Tags
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        UpVotes,
        DownVotes,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        ViewCount,
        TagCount,
        Tags,
        RANK() OVER (ORDER BY Score DESC, UpVotes DESC, ViewCount DESC) AS Rank
    FROM 
        TopPosts
)
SELECT 
    RP.Rank,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.UpVotes,
    RP.DownVotes,
    RP.AnswerCount,
    RP.CommentCount,
    RP.FavoriteCount,
    RP.ViewCount,
    RP.TagCount,
    RP.Tags
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10 -- Get top 10 ranked posts
ORDER BY 
    RP.Rank;
